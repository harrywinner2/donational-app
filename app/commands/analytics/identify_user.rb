require 'segment/analytics'

module Analytics
  Engine ||= Segment::Analytics.new(write_key: ENV.fetch('SEGMENT_RUBY_WRITE_KEY'))

  class IdentifyUser < ApplicationCommand
    required do
      string :user_id
    end

    optional do
      hash :traits do
        duck :*
      end
    end

    def execute
      Engine.identify(
        user_id: user_id,
        traits: traits
      )
    end
  end
end
