%w[6.1 7.0 7.1 7.2].each do |version|
  appraise "rails.#{version}" do
    gem "activesupport", "~> #{version}.0"
    gem "activerecord", "~> #{version}.0"

    if version.start_with?("7") || version.start_with?("8")
      gem "datadog", '~> 2.0'
    else
      gem "ddtrace", "> 1.0"
    end
  end
end
