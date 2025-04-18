# frozen_string_literal: true

class VerifyLinkService < BaseService
  def call(field)
    @link_back = ActivityPub::TagManager.instance.url_for(field.account)
    @url       = field.value_for_verification

    perform_request!

    return unless link_back_present?

    field.mark_verified!
  rescue *Truecolors::HTTP_CONNECTION_ERRORS, Addressable::URI::InvalidURIError, Truecolors::HostValidationError, Truecolors::LengthValidationError, IPAddr::AddressFamilyError => e
    Rails.logger.debug { "Error fetching link #{@url}: #{e}" }
    nil
  end

  private

  def perform_request!
    @body = Request.new(:get, @url).add_headers('Accept' => 'text/html').perform do |res|
      res.code == 200 ? res.truncated_body : nil
    end
  end

  def link_back_present?
    return false if @body.blank?

    links = Nokogiri::HTML5(@body).xpath('(//a|//link)[@rel][nokogiri:link_rel_include(@rel, "me")]', NokogiriHandler)

    if links.any? { |link| link['href']&.downcase == @link_back.downcase }
      true
    elsif links.empty?
      false
    else
      link_redirects_back?(links.first['href'])
    end
  end

  def link_redirects_back?(test_url)
    return false if test_url.blank?

    redirect_to_url = Request.new(:head, test_url, follow: false).perform do |res|
      res.headers['Location']
    end

    redirect_to_url == @link_back
  end
end
