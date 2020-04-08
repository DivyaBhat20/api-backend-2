class Api::V1::BooksController < ApplicationController
  before_action :load_book, only: [:show, :update, :destroy]
  before_action :ensure_user_is_owner_of_book, only: [:update, :destroy]

  def index
    books = Book.all
    # cookies[:name] = 'febin'
    # response.set_header('Access-Control-Allow-Origin', '*')
    render json: {status: 'SUCCESS', data: books}
  end

  def show
    if @book.present?
      render json: {status: 'SUCCESS', message: 'Fetched book', data: @book}, status: :ok
    else
      render json: {status: 'ERROR', message: 'Book not found'}, status: :unprocessable_entity
    end
  end

  def create
    book = Book.new(book_params)
    book.user = fetch_user_from_token(params[:token])
    if book.save
      render json: {status: 'SUCCESS', message: 'Book created successfully', data: book}, status: :ok
    else
      render json: {status: 'ERROR', message: 'Book not created', data: book.errors}, status: :unprocessable_entity
    end
  end

  def update
    @book.assign_attributes(book_params)
    if @book.save
      render json: {status: 'SUCCESS', message: 'Updated book successfully', data: @book}, status: :ok
    else
      render json: {status: 'ERROR', message: 'Failed to update book', data: @book.errors}, status: :unprocessable_entity
    end
  end

  def destroy
    if @book.destroy
      render json: {status: 'SUCCESS', message: 'Deleted book successfully', data: @book}, status: :ok
    else
      render json: {status: 'ERROR', message: 'Failed to delete book', data: @book.errors}, status: :unprocessable_entity
    end
  end

  private

  def load_book
    @book = Book.find_by(id: params[:id])
  end

  def ensure_user_is_owner_of_book
    user = fetch_user_from_token(params[:token])
    unless user == @book.user
        render json: {status: 'ERROR', message: 'You are not the owner of this book'}, status: :unprocessable_entity
    end
  end

  def fetch_user_from_token(token)
    UserValidationToken.find_by_token(token).user
  end

  def book_params
    params
      .require(:book)
      .permit(:name,
              :description,
	      :user
      )
  end
end
