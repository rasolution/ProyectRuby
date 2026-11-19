class TransactionsController < ApplicationController
  before_action :set_transaction, only: [:show, :edit, :update, :destroy]

  def index
    @transactions = Transaction.order(:id)
  end

  def show; end
  def edit; end

  def new
    @transaction = Transaction.new
  end

  def create
    @transaction = Transaction.new(transaction_params)
    respond_to do |format|
      if @transaction.save
        format.html { redirect_to @transaction, status: :see_other, notice: 'Intercambio creado.' }
        format.json { render :show, status: :created, location: @transaction }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @transaction.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @transaction.update(transaction_params)
        format.html { redirect_to @transaction, status: :see_other, notice: 'Intercambio actualizado.' }
        format.json { render :show, status: :ok }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @transaction.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @transaction.destroy!
    respond_to do |format|
      format.html { redirect_to transactions_url, status: :see_other, notice: 'Intercambio eliminado.' }
      format.json { head :no_content }
    end
  end

  private

  def set_transaction
    @transaction = Transaction.find(record_id)
  end

  def transaction_params
    params.require(:transaction).permit(:offert_product_id, :require_product_id)
  end
end
