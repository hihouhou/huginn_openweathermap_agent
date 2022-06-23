module Agents
  class OpenweathermapAgent < Agent
    include FormConfigurable
    can_dry_run!
    no_bulk_receive!
    default_schedule "never"

    description <<-MD
      The Weather Agent creates an event for the day's weather at a given `location`.

      I created this agent because about [Dark Sky](https://darksky.net/dev/) -> "We are no longer accepting new signups".

      The weather forecast information is provided by Openweathermap. 

      The `lat` (latitude) and `lon` (longitude) must be configured for current_weather. For example, San Francisco would be `37.7771,-122.4196`.

      You must set up an [API key for Openweathermap](https://home.openweathermap.org/api_keys) in order to use this Agent.

      Set `expected_update_period_in_days` to the maximum amount of time that you'd expect to pass between Events being created by this Agent.

    MD

    event_description <<-MD
      Events look like this:

          {
            "coord": {
              "lon": 2.3333,
              "lat": 48.8667
            },
            "weather": [
              {
                "id": 800,
                "main": "Clear",
                "description": "clear sky",
                "icon": "01d"
              }
            ],
            "base": "stations",
            "main": {
              "temp": 300.35,
              "feels_like": 300.5,
              "temp_min": 298.87,
              "temp_max": 301.01,
              "pressure": 1008,
              "humidity": 46
            },
            "visibility": 10000,
            "wind": {
              "speed": 3.6,
              "deg": 210
            },
            "clouds": {
              "all": 0
            },
            "dt": 1656004271,
            "sys": {
              "type": 2,
              "id": 2041230,
              "country": "FR",
              "sunrise": 1655956045,
              "sunset": 1656014290
            },
            "timezone": 7200,
            "id": 6545270,
            "name": "Palais-Royal",
            "cod": 200
          }
    MD

    def default_options
      {
        'type' => '',
        'token' => '',
        'limit' => '',
        'lat' => '',
        'lon' => '',
        'debug' => 'false',
        'emit_events' => 'true',
        'expected_receive_period_in_days' => '2',
      }
    end

    form_configurable :debug, type: :boolean
    form_configurable :emit_events, type: :boolean
    form_configurable :expected_receive_period_in_days, type: :string
    form_configurable :type, type: :array, values: ['current_weather']
    form_configurable :token, type: :string
    form_configurable :limit, type: :string
    form_configurable :lat, type: :string
    form_configurable :lon, type: :string
    def validate_options
      errors.add(:base, "type has invalid value: should be 'current_weather'") if interpolated['type'].present? && !%w(current_weather).include?(interpolated['type'])

      errors.add(:base, "lon must be provided") if not interpolated['lon'].present? && interpolated['type'] == 'current_weather'

      errors.add(:base, "lat must be provided") if not interpolated['lat'].present? && interpolated['type'] == 'current_weather'

      unless options['token'].present?
        errors.add(:base, "token is a required field")
      end

      if options.has_key?('emit_events') && boolify(options['emit_events']).nil?
        errors.add(:base, "if provided, emit_events must be true or false")
      end

      if options.has_key?('debug') && boolify(options['debug']).nil?
        errors.add(:base, "if provided, debug must be true or false")
      end

      unless options['expected_receive_period_in_days'].present? && options['expected_receive_period_in_days'].to_i > 0
        errors.add(:base, "Please provide 'expected_receive_period_in_days' to indicate how many days can pass before this Agent is considered to be not working")
      end
    end

    def working?
      event_created_within?(options['expected_receive_period_in_days']) && !recent_error_logs?
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        interpolate_with(event) do
          log event
          trigger_action
        end
      end
    end

    def check
      trigger_action
    end

    private

    def log_curl_output(code,body)

      log "request status : #{code}"

      if interpolated['debug'] == 'true'
        log "body"
        log body
      end

      if interpolated['emit_events'] == 'true'
        create_event payload: body
      end

    end

    def get_current_weather()

      uri = URI.parse("https://api.openweathermap.org/data/2.5/weather?lat=#{interpolated['lat']}&lon=#{interpolated['lon']}&appid=#{interpolated['token']}")
      response = Net::HTTP.get_response(uri)

      log_curl_output(response.code,response.body)

    end

    def trigger_action

      case interpolated['type']
      when "current_weather"
        get_current_weather()
      else
        log "Error: type has an invalid value (#{type})"
      end
    end
  end
end
