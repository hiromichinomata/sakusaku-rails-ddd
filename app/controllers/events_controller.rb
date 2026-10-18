class EventsController < ApplicationController
  def index
    @events = Event.order(:starts_at)
  end

  def show
    @event = Event.find(params[:id])
    @reservation = @event.reservations.build
  end

  def new
    @event = Event.new
  end

  def create
    @event = Event.new(event_params)

    saved = Event.transaction do
      @event.save && Ticketing::InventoryRepository.new.add(
        Ticketing::Inventory.new(event_id: @event.id, capacity: @event.capacity)
      )
    end

    if saved
      redirect_to @event, notice: "イベントを登録しました。"
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def event_params
    params.expect(event: %i[title description venue starts_at capacity price])
  end
end
