# frozen_string_literal: true

module Api
  module V1
    class ChatRoomsController < Api::BaseController
      before_action :require_user!
      before_action :set_chat_room, except: [:index, :create]

      # GET /api/v1/chat_rooms
      def index
        @chat_rooms = ChatRoom.where(public: true)
                              .or(ChatRoom.where(creator_id: current_user.id))
                              .order(created_at: :desc)
                              .page(params[:page])
                              .per(20)

        render json: @chat_rooms, each_serializer: REST::ChatRoomSerializer
      end

      # GET /api/v1/chat_rooms/:id
      def show
        authorize @chat_room, :show?
        render json: @chat_room, serializer: REST::ChatRoomSerializer
      end

      # POST /api/v1/chat_rooms
      def create
        @chat_room = ChatRoom.new(chat_room_params)
        @chat_room.creator = current_user

        if @chat_room.save
          # Trigger background job to create room on XMPP server
          CreateXmppRoomWorker.perform_async(@chat_room.id)
          render json: @chat_room, serializer: REST::ChatRoomSerializer, status: 201
        else
          render json: { error: @chat_room.errors.full_messages.join(', ') }, status: 422
        end
      end

      # GET /api/v1/chat_rooms/:id/messages
      def messages
        authorize @chat_room, :show?

        @messages = @chat_room.chat_messages
                              .order(created_at: :desc)
                              .page(params[:page])
                              .per(20)

        render json: @messages, each_serializer: REST::ChatMessageSerializer
      end

      def update
        if @chat_room.update(chat_room_params)
          render json: @chat_room
        else
          render json: { error: @chat_room.errors.full_messages.join(', ') }, status: 422
        end
      end

      def destroy
        @chat_room.destroy
        head 204
      end

      private

      def set_chat_room
        @chat_room = ChatRoom.find(params[:id])
      end

      def chat_room_params
        params.permit(chat_room: [:name, :public])[:chat_room]
      end
    end
  end
end