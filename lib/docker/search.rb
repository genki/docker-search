require File.join(__dir__, "search/version")
require 'optparse'
require 'json'
require 'net/https'
require 'terminal-display-colors'

module Docker
  class Search

    def self.run
      config_path = "~/.docker/config.json"
      action = :search
      opt = OptionParser.new
      def opt.version; VERSION end
      opt.on('-c config_file_path'){|v| config_path = v}
      opt.on('-l', 'list up registries'){action = :list}
      opt.parse! ARGV
      search = new JSON.load(open(File.expand_path config_path).read)
      search.send action, *ARGV
    end

    def initialize(config)
      @hosts = {}
      config['auths'].each do |host, c|
        user, pass = c["auth"].unpack('m')[0].split(':', 2)
        @hosts[host] = [user, pass]
      end
    end

    def search(*names)
      @hosts.each do |(k,v)|
        puts "Searching #{k} ...".blue
        uri = URI(k)
        case uri.path
        when %r{/v1\b}
          STDERR.puts "v1 is not supported.".yellow
        else
          http = Net::HTTP.new k, 443
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          http.start do
            req = Net::HTTP::Get.new "/v2/_catalog"
            req.basic_auth *v
            res = http.request req
            json = JSON.load res.body
            repos = json['repositories']
            names.each{|n| repos = repos.select{|r| r.index n}}
            puts repos
          end
        end
      end
    end

    def list
      @hosts.each_with_index do |(k,v),i|
        puts "#{i + 1}. #{k}"
      end
    end

  private
    def fetch(url)
    end
  end
end
