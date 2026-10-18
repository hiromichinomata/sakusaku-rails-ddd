module Ticketing
  class OfferReleasedSeatsJob < ApplicationJob
    queue_as :default

    def perform(event_id)
      OfferReleasedSeats.new.call(event_id: event_id)
    end
  end
end
