# frozen_string_literal: true

# An API client for the NicoSeiga XML API.
class NicoSeigaApiClient
  extend Memoist
  XML_API = "https://seiga.nicovideo.jp/api"

  attr_reader :http, :user_session

  def initialize(work_id:, type:, user_session: Danbooru.config.nico_seiga_user_session, http: Danbooru::Http.new)
    @work_id = work_id
    @work_type = type
    @user_session = user_session
    @http = http
  end

  def image_ids
    case @work_type
    when "illust"
      [api_response["id"]]
    when "manga"
      manga_api_response.map do |x|
        case x["meta"]["source_url"]
        when %r{/thumb/(\d+)\w}i then Regexp.last_match(1)
        when %r{nicoseiga\.cdn\.nimg\.jp/drm/image/\w+/(\d+)\w}i then Regexp.last_match(1)
        end
      end
    end
  end

  def title
    api_response["title"]
  end

  def description
    api_response["description"]
  end

  def tags
    api_response.dig("tag_list", "tag").to_a.map { |t| t["name"] }.compact
  end

  def user_id
    api_response["user_id"]
  end

  def user_name
    case @work_type
    when "illust"
      api_response["nickname"]
    when "manga"
      user_api_response(user_id)["nickname"]
    end
  end

  def api_response
    case @work_type
    when "illust"
      resp = get("https://sp.seiga.nicovideo.jp/ajax/seiga/im#{@work_id}")
      return {} if resp.blank? || resp.code.to_i == 404
      api_response = JSON.parse(resp)["target_image"]

    when "manga"
      resp = get("#{XML_API}/theme/info?id=#{@work_id}")
      return {} if resp.blank? || resp.code.to_i == 404
      api_response = Hash.from_xml(resp.to_s)["response"]["theme"]
    end

    api_response || {}
  rescue JSON::ParserError
    {}
  end

  def manga_api_response
    resp = get("https://ssl.seiga.nicovideo.jp/api/v1/app/manga/episodes/#{@work_id}/frames")
    return {} if resp.blank? || resp.code.to_i == 404
    JSON.parse(resp)["data"]["result"]
  rescue JSON::ParserError
    {}
  end

  def user_api_response(user_id)
    resp = get("#{XML_API}/user/info?id=#{user_id}")
    return {} if resp.blank? || resp.code.to_i == 404
    Hash.from_xml(resp.to_s)["response"]["user"]
  end

  def cookies
    {
      skip_fetish_warning: "1",
      user_session: user_session,
    }
  end

  def get(url)
    http.cookies(cookies).cache(1.minute).get(url)
  end

  def head(url)
    http.cookies(cookies).cache(1.minute).head(url)
  end

  memoize :api_response, :manga_api_response, :user_api_response
end
