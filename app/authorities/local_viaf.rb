# use VIAF name authority as a local qa authority
require 'rest-client'

# can't actually be used by itself; use as parent of a subauth class.
class LocalViaf

  # submit the query and return the results
  def search_subauthority(subauth, q)
    ns1_uri = 'http://www.loc.gov/zing/srw/'
    terms_uri = 'http://viaf.org/viaf/terms#'
    results = []
    response = RestClient.get build_query_url(subauth, q)
    doc = Nokogiri::XML response
    records = doc.xpath('//ns1:record', 'ns1' => ns1_uri)
    records.each do |r|
      #data = r.css('recordData').first
      id = r.xpath('ns1:recordData//terms:viafID', 'ns1' => ns1_uri, 'terms' => terms_uri).first.content
      type = r.xpath('ns1:recordData//terms:nameType', 'ns1' => ns1_uri, 'terms' => terms_uri).first.content
      headings = r.xpath('ns1:recordData//terms:mainHeadings/terms:data', 'ns1' => ns1_uri, 'terms' => terms_uri)
      first = lc = first_source = ''
      headings.each do |h|
        text = h.xpath('terms:text', 'terms' => terms_uri).first.content
        sources = h.xpath('terms:sources/terms:s', 'terms' => terms_uri).map { |s| s.content.downcase }
        if first.empty?
          first = text if
          first_source = sources.join(', ')
        end
        if sources.include? 'lc'
          lc = text
        end
      end
      text = lc.empty? ? first : lc
      source = lc.empty? ? first_source : 'lc'
      results << { id: id, type: type, value: text, label: "#{text} (#{source.upcase})" }
    end
    return results
  end

  def build_query_url(subauth, q)
    query = "local.#{subauth} = \"#{q}\""
    url = "http://viaf.org/viaf/search?query=#{URI.escape(query)}&recordSchema=http%3A%2F%2Fviaf.org%2FBriefVIAFCluster&maximumRecords=20&startRecord=1&sortKeys=holdingscount&httpAccept=text/xml"
  end
end
