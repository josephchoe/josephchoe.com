module Jekyll
  class Placeholder < Generator
    safe true
    priority :low

    def generate(site)
      site.posts.docs.each do |item|
        permalink = item.data["permalink"]

        if permalink.nil?
          next
        end

        keys = permalink.scan /(?<=:)\w+/

        keys.each do |key|
          if item.url_placeholders.keys.include?(key)
            next
          end

          if !item.data.key?(key)
            next
          end

          substitution = item.data[key].to_s
          # and if it is available, substitute it for the value
          item.data["permalink"].gsub!(":#{key}", substitution)
        end
      end
    end
  end
end
