module Bitmovin::Encoding::Manifests
  class HlsManifest < Bitmovin::Resource
    include Bitmovin::ChildCollection
    init("/v1/encoding/manifests/hls")

    def initialize(hash = {})
      hsh = ActiveSupport::HashWithIndifferentAccess.new(underscore_hash(hash))
      super(hash)
      @outputs = (hsh[:outputs] || []).map { |output| Bitmovin::Encoding::StreamOutput.new(output) }
      @audio_media = nil
      @video_media = nil
      @variant_media = nil
    end

    child_collection(:audio_media, "/v1/encoding/manifests/hls/%s/media/audio", [:id], AudioMedia)
    child_collection(:video_media, "/v1/encoding/manifests/hls/%s/media/video", [:id], VideoMedia)
    child_collection(:variant_stream, "/v1/encoding/manifests/hls/%s/streams", [:id], VariantStream)

    attr_accessor :outputs, :manifest_name

    def persisted?
      !@id.nil?
    end

    def reload!
      @audio_media = nil
      @video_media = nil
      @variant_media = nil
    end

    def start!
      path = File.join("/v1/encoding/manifests/hls/", @id, "start")
      Bitmovin.client.post(path)
    end

    def full_status
      path = File.join("/v1/encoding/manifests/hls/", @id, "status")
      response = Bitmovin.client.get(path)
      hash_to_struct(result(response))
    end

    def status
      full_status.status
    end

    def progress
      full_status.progress
    end

    private

    def collect_attributes
      val = Hash.new
      [:name, :description, :manifest_name].each do |name|
        json_name = ActiveSupport::Inflector.camelize(name.to_s, false)
        val[json_name] = instance_variable_get("@#{name}")
      end
      val["outputs"] = @outputs.map { |o| o.send(:collect_attributes) }
      val
    end
  end
end
