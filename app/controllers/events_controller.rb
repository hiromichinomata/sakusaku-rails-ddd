class EventsController < ApplicationController
  def index
    @events = Event.order(:starts_at)
  end

  def show
    @event = Event.find(params[:id])
  end
end
