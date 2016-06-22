Gem::Specification.new do |spec|
  spec.name = 'wanko'
  spec.version = '0.4.0'
  spec.date = Time.now.utc.strftime('%Y-%m-%d')
  spec.required_ruby_version = '>=2.0.0'
  spec.license = 'WTFPL'

  spec.summary = 'RSS Torrent Fetcher'
  spec.description = <<-DESCRIPTION
    Fetches torrent file links from RSS feeds based on user-specified rules. The
    links can be printed to stdout or sent to Transmission for download, or the
    torrent files can be downloaded to a watchdir for processing by other torrent
    clients.
  DESCRIPTION
  spec.requirements << 'Transmission bittorrent client (optional)'

  spec.author = 'Ookami Kenrou'
  spec.email = 'ookamikenrou@gmail.com'
  spec.homepage = 'https://github.com/kemonomachi/wanko'

  spec.files = Dir['lib/**/*.rb'] + ['bin/wanko', 'LICENSE', 'README']
  spec.executables = ['wanko']

  spec.add_dependency 'terminal-table', ['~> 1.6']
end

