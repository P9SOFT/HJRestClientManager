Pod::Spec.new do |s|

  s.name         = "HJRestClientManager"
  s.version      = "1.0.0"
  s.summary      = "Simple and flexible handling module for REST API based on Hydra framework."
  s.homepage     = "https://github.com/P9SOFT/HJRestClientManager"
  s.license      = { :type => 'MIT' }
  s.author       = { "Tae Hyun Na" => "taehyun.na@gmail.com" }

  s.ios.deployment_target = '8.0'
  s.requires_arc = true

  s.source       = { :git => "https://github.com/P9SOFT/HJRestClientManager.git", :tag => "1.0.0" }
  s.source_files  = "Sources/*.swift"
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.dependency 'HJHttpApiExecutor', '~> 2.0.1'
  s.dependency 'HJResourceManager', '~> 2.0.1'

end
