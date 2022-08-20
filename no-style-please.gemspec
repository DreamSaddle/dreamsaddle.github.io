# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "DreamSaddle"
  spec.version       = "0.0.1"
  spec.authors       = ["DreamSaddle"]
  spec.email         = ["dreamsaddle496@gmail.com"]

  spec.summary       = "Github website pages."
  spec.homepage      = "https://github.com/DreamSaddle"

  spec.files         = `git ls-files -z`.split("\x0").select { |f| f.match(%r!^(assets|_layouts|_includes|_sass|LICENSE|README|_config\.yml)!i) }

  spec.add_runtime_dependency "jekyll", "~> 3.9.0"
  spec.add_runtime_dependency "jekyll-feed", "~> 0.15.1"
  spec.add_runtime_dependency "jekyll-seo-tag", "~> 2.7.1"

end
