Pod::Spec.new do |s|
  s.name             = "BatchedHandlers"
  s.version          = "0.2.0"
  s.summary          = "A helper class to handle multiple completion handlers for a task"
  s.homepage         = "https://github.com/dtorres/BatchedHandlers"
  s.license          = 'MIT'
  s.author           = { "Diego Torres" => "contact@dtorres.me" }
  s.source           = { :git => "https://github.com/dtorres/BatchedHandlers.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/dtorres'

  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.8'

  s.requires_arc = true
  s.source_files = 'Classes/*.{h,m}'
  s.public_header_files = 'Classes/BHManager.h'
end
