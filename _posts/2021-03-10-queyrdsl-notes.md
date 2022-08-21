---
title: "QueryDSL记录"
layout: post
---

🍎

本文主要是记录我在工作中使用[QueryDSL](http://www.querydsl.com/)所遇到的一些问题以及解决办法。

## 使用 find_in_set 函数

某次需要使用 **find_in_set** 作为条件进行查询，但是经过测试报错如下:

```sql
QuerySyntaxException: unexpected AST node
```

**解决办法**

MYSQL原生sql只需要使用下面的格式即可

```sql
select * from table where id find_in_set(1, '1,2,3');
```

querydsl可以使用其 `BooleanTemplate` 完成此表达式的构建

但是, JPA就必须使用一下格式

```java
BooleanTemplate booleanTemplate =
    Expressions.booleanTemplate("find_in_set({0}, {1}) > 0", 1, "1,2,3");
// 1,2,3可以更换为数据库字段(querydsl表达式)
```

区别在哪呢？就是 `> 0`

## 子查询结果排序

比如需要根据某汇总数据结果进行倒序

原生sql格式大致如下, 需要根据 `t2_count` 进行排序

```sql
select t.id, 
    (select count(1) from table2 t1 where t1.id = t.t_id) 
        as t2_count 
from table t order by t2_count desc;
```

**解决办法**

querydsl中可以使用 `StringTemplate` 对as别名字段进行排序

```java
//查询列使用
select(Expressions.as(t2Count, "t2_count"))

//排序条件使用
orderBy(new OrderSpecifier(Order.DESC, 
    Expressions.stringTemplate("t2_count")));
```

## ifnull

原生sql中可以使用

```sql
select ifnull(sum(count), 0) from table
```

如果 `sum(count)` 的结果为null, 则默认使用0代替

在querydsl中语法如下

```sql
//就是使用 coalesce(0)
select(QTable.table.count.sum().coalesce(0)).from(QTable.table)
```

## 对查询结果某些列进行计算作为条件使用

比如查询学生的考试分数，表中有`总分`和`平均分`字段，需要找出`总分 - 平均分 > 30`的记录。

原生sql大致如下

```sql
select sum_score, avg_score, student_name from stu_score where sum_score - avg_score > 30
```

querydsl实现

```java
JPAQuery<Tuple> jpaQuery = select(QStuScore.stuscore.sumScore, QStuScore.stuscore.avgScore).from(QStuScore.stuscore);
//添加条件
jpaQuery.where(Expressions.numberOperation(Integer.class, Ops.SUB,QStuScore.stuscore.sumScore, QStuScore.stuscore.avgScore).gt(30));
//说明
//Expressions.numberOperation(Integer.class, Ops.SUB,QStuScore.stuscore.sumScore, QStuScore.stuscore.avgScore)
//表示创建一个数字操作, 类型为Integer, Ops.SUB表示减操作, 后面两个就是操作的列, gt(30)表示结果需大于30
```

## 聚合函数中使用子查询

原生 sql 大致如下：

```sql
SELECT 
  id,
  SUM(SELECT SUM(score) FROM table2 t2 t2.tid = t1.id) AS scoreSum
FROM table t1
GROUP BY t1.number
```

querydsl 实现：

```java
var subQuery = JPAExpressions.select(QTable2.table2.score.sum()).from(QTable2.table2).where(...);
var sumSubQuery = Expressions.as(Expressions.numberOperation(Integer.class, Ops.AggOps.SUM_AGG, subQuery), "scoreSum");
// 再将 sumSubQuery 放入到另一个 select 中作为子查询使用即可
```

使用 `Expressions.numberOperation(Integer.class, Ops.AggOps.SUM_AGG, 子查询)` 即可实现。

## 使用 SQLQueryFactory 进行原生 SQL 查询

### 创建 SQLQueryFactory 实例

```java
SQLQueryFactory sqlQueryFactory = new SQLQueryFactory(
 new Configuration(new MySQLTemplates()),
 dataSource
);
```

使用 `SQLQueryFactory` 就不能直接使用 querydsl 生成的 `Qxxxx` 了。

比方有实体类如下：

```java
@Entity
@Table(name = "user_info")
public class UserInfo {
    private Long id;
    private String userName;
    private String tel;
    private SexEnum sex;
}
```

对应的就会有一个 `QUserInfo` 类。

#### 根据 userName 字段进行模糊搜索

`JPAQueryFactory` 实现如下：

```java
JPAQueryFactory qf;
QUserInfo qUserInfo = QUserInfo.qUserInfo;
qf.selectFrom(qUserInfo).where(qUserInfo.userName.like("%Tom%")).fetch();
```

`SQLQueryFactory` 实现如下：

```java
import com.querydsl.core.types.dsl.Expressions;

SQLQueryFactory qf = new SQLQueryFactory(
 new Configuration(new MySQLTemplates()),
 dataSource
);
// 下面的 user_info 字符串对应实体 UserInfo 的表名
QUserInfo qUserInfo = new QUserInfo("user_info");
// 下面这一行生成 sql 后就是: user_info.user_name
StringPath userNamePath = Expressions.stringPath(qUserInfo, "user_name");
qf.select().from(qUserInfo).where(userNamePath.like("%Tom%")).fetch();
```

主要就是通过 `Expressions` 类构建出各种 `Path` 进行查询字段或查询条件的处理。

## SQLQueryFactory 原生 SQL 查询枚举结果处理

通过上面的例子很明显的可以猜到在 `Expressions` 类中有构造枚举 Path 的方法。这个方法就是 `enumPath`。使用方式如下：

```java
EnumPath<SexEnum> sexPath = Expressions.enumPath(SexEnum.class, qUserInfo, "sex");
```

这样我们通过 `sexPath` 来构造条件等是完全没有问题的。但是直接使用 `sexPath` 放在 select 块中是不行的，通过调试代码可以发现查询出的 `sex` 字段是 `String` 类型，而非 `SexEnum` 类型，导致在调用 setter 时失败。

如果要查询枚举字段，则需要通过 `EnumConversion` 进行一次转换，如下：

```java
EnumConversion<SexEnum> enumConversion = new EnumConversion<SexEnum>(sexPath);
```

在 select 块中就需要使用 `enumConversion`。

```java
select(Expressions.as(enumConversion, "sex")).from(qUserInfo);
```
