class AppnexusApi::Resource

  attr_reader :dbg_info, :json

  def initialize(json, service, dbg_info = nil)
    @json = json
    @service = service
    @dbg_info = dbg_info
  end

  def update(route_params={}, body_params={})
    resource = @service.update(id, route_params, body_params)
    @json = resource.json
    self
  end

  def delete(route_params={})
    @service.delete(id, route_params)
  end

  def method_missing(sym, *args, &block)
    if @json.respond_to?(sym)
      @json.send(sym, *args, &block)
    elsif @json.has_key?(sym.to_s)
      return @json[sym.to_s]
    else
      super(sym, *args, &block)
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    @json.respond_to?(method_name) || @json.has_key?(method_name.to_s) || super
  end

  def to_s
    @json.inspect
  end
end
