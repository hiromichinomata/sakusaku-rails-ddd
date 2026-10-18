class EventsController < ApplicationController
  def index
    @events = Event.order(:starts_at)
  end

  def show
    @event = Event.find(params[:id])
  end

  def new
    @event = Event.new
  end

  def create
    @event = Event.new(event_params)

    if @event.save
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
