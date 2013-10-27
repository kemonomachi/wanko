Gem::Specification.new do |spec|
  spec.name = 'wanko'
  spec.version = '0.0.0'
  spec.date = Time.now.utc.strftime('%Y-%m-%d')
  spec.required_ruby_version = '>=2.0.0'
  spec.license = 'WTFPL'

  spec.add_runtime_dependency 'formatador'

  spec.summary = 'Simple RSS torrent downloader for Transmission'
  spec.description = <<-DESCRIPTION
    Reads RSS torrent feeds and passes download links to Transmission.
    Rules for which items to download are specified as regexps.
    Can also print the links to stdout.
    No built in daemon, run manually or as a cron job.
  DESCRIPTION
  spec.requirements << 'Transmission bittorrent client (optional)'

  spec.author = 'Ookami Kenrou'
  spec.email = 'ookamikenrou@gmail.com'

  spec.files = Dir['lib/**/*.rb'] + ['bin/wanko', 'LICENSE']
  spec.executables = ['wanko']
end

