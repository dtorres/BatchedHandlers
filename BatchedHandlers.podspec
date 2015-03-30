Pod::Spec.new do |s|
  s.name             = "BatchedHandlers"
  s.version          = "0.1.0"
  s.summary          = "A short description of BatchedHandlers."
  s.description      = <<-DESC
                       An optional longer description of BatchedHandlers

                       * Markdown format.
                       * Don't worry about the indent, we strip it!
                       DESC
  s.homepage         = "https://github.com/dtorres/BatchedHandlers"
  s.license          = 'MIT'
  s.author           = { "Diego Torres" => "contact@dtorres.me" }
  s.source           = { :git => "https://github.com/dtorres/BatchedHandlers.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/dtorres'

  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.8'

  s.requires_arc = true
  s.source_files = 'Classes/BHBlockManager.{h,m}'
end
