class PasswordsController < ApplicationController

  class SendResetTokenJob
    include SuckerPunch::Job

    def perform(account_id)
    end
  end

  # params:
  # * username
  def edit
    if account = Account.named(params[:username]).take
      # SECURITY NOTE:
      #
      # using a background job will:
      # * insulate the user from back channel network request overhead
      # * protect this endpoint from user enumeration timing attacks
      SendResetTokenJob.perform_async(account.id)
    end

    # no user enumeration at this endpoint
    head :ok
  end
end
