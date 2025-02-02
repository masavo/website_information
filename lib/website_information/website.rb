require 'nokogiri'
require 'open-uri'

module WebsiteInformation
  class Website
    def initialize(url)
      @params = WebsiteInformation::Params::Site.new(url)
      scrape(url)
    end

    def scraped_params
      @params
    end

    private

    def scrape(url)
      doc = ::Nokogiri::HTML(URI.open(url), nil, 'UTF-8')
      @params.title = doc.title
      @params.meta.description = doc.css('//meta[name$="description"]/@content').to_s
      @params.meta.keyword = doc.css('//meta[name$="keyword"]/@content')
      @params.og.site_name = doc.css('//meta[property$="og:site_name"]/@content').to_s
      @params.og.description = doc.css('//meta[property="og:description"]/@content').to_s
      @params.og.title = doc.css('//meta[property="og:title"]/@content').to_s
      @params.og.url = doc.css('//meta[property="og:url"]/@content').to_s
      @params.og.type = doc.css('//meta[property="og:type"]/@content').to_s
      @params.og.image = doc.css('//meta[property="og:image"]/@content').to_s
      favicon(doc, url)
      feed(doc)
      sns(doc)
    end

    def favicon(doc, url)
      favicon = doc.css('//link[@rel="shortcut icon"]/@href').to_s
      favicon = doc.css('//link[@rel="icon"]/@href').to_s          if favicon.empty?
      favicon = doc.css('//link[@type="image/x-icon"]/@href').to_s if favicon.empty?
      favicon = '/favicon.ico' if favicon.empty?

      require 'uri'
      uri = URI.parse(favicon)
      if uri.host.nil?
        uri = URI.parse(url)
        @params.favicon = "#{uri.scheme}://#{uri.host}#{favicon}"
      else
        @params.favicon = favicon
      end
    end

    def feed(doc)
      @params.feed = doc.css('//link[@rel="alternate"][@type="application/atom+xml"]/@href')[0].to_s
      @params.feed = doc.css('//link[@rel="alternate"][@type="application/rss+xml"]/@href')[0].to_s if @params.feed.empty?
    end

    def sns(doc)
      # scrape facebook url from page plugin (https://developers.facebook.com/docs/plugins/page-plugin/)
      @params.sns.facebook = doc.css('//div[class$="fb-page"]/@data-href')[0].to_s
      # scrape twitter url from embedded timelines (https://dev.twitter.com/web/embedded-timelines/list)
      @params.sns.twitter = doc.css('//a[class$="twitter-timeline"]/@href')[0].to_s
    end
  end
end
