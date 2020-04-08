class Api::V1::VideosController < ApplicationController
  def create
    video = File.open(params['inputFile'])
    response = create_initial_vimeo_post_request(video)
    iframe = response["embed"]["html"]
    name = response["name"]
    uri = response["uri"]
    logger.info("***************** #{response}")
    complete_vimeo_video_upload(video, response)
    
    render json: {status: 'SUCCESS', data: {iframe: iframe, name: name, uri: uri}}, status: :ok
  end

  private

  def create_initial_vimeo_post_request(video)
    api_endpoint = Rails.application.secrets.vimeo[:video_post_endpoint]
    headers = {'Content-Type' => 'application/json'}
    headers['Authorization'] = "bearer #{Rails.application.secrets.vimeo[:authorization_token]}"
    headers['Accept'] = 'application/vnd.vimeo.*+json;version=3.4'
    body = { "upload": { "approach": "tus", "size": "#{video.size.to_s}" }, "name": SecureRandom.alphanumeric(10) }
    options = { headers: headers, body: body.to_json }
    response = HTTParty.post(api_endpoint, options)
    JSON.parse(response.parsed_response)
  end

  def complete_vimeo_video_upload(video, response)
    headers = {'Content-Type' => 'application/offset+octet-stream'}
    headers['Tus-Resumable'] = '1.0.0'
    headers['Upload-Offset'] = '0'
    video.rewind
    video_content = video.read(video.size).to_s
    api_endpoint = response["upload"]["upload_link"]
    begin
      body = video_content[headers['Upload-Offset'].to_i..-1]
      options = { headers: headers, body: body }
      response = HTTParty.patch(api_endpoint, options)
      headers['Upload-Offset'] = response.headers['upload-offset']
    end while headers['Upload-Offset'].to_i != video.size
  end
end
