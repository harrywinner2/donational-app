require 'stripe'

module Payments
  module PlatformAccount
    class ChargeCustomerCard < ApplicationCommand
      required do
        string :account_id, empty: false
        string :currency, empty: false
        integer :donation_amount_cents
        model :payment_method
      end

      optional do
        hash :metadata do
          string :donor_id
          string :portfolio_id
          string :contribution_id
        end
        integer :platform_fee_cents, default: 0
        integer :tips_cents, default: 0
      end

      def execute
        OpenStruct.new(
          payment_processor_fees_cents:,
          receipt: payment_intent
        )
      rescue Stripe::CardError, Stripe::InvalidRequestError, Stripe::StripeError => e
        add_error(:customer, :stripe_error, e.message)

        nil
      end

      protected

      def payment_processor_fees_cents
        return unless balance_transaction.present?

        balance_transaction[:fee_details].detect { |f| f[:type] == 'stripe_fee' }[:amount]
      end

      def balance_transaction
        payment_intent[:charges][:data][0][:balance_transaction]
      end

      def payment_intent
        @payment_intent ||= Stripe::PaymentIntent.create(
          {
            amount: donation_amount_cents + tips_cents,
            application_fee_amount: platform_fee_cents + tips_cents,
            confirm: true,
            currency:,
            expand: ['charges.data.balance_transaction'],
            metadata:,
            payment_method: single_use_payment_method_cloned_to_connected_account,
            payment_method_types: ['card'],
            off_session: true
          },
          stripe_account: account_id
        )
      end

      # https://stripe.com/docs/payments/payment-methods/connect#cloning-payment-methods
      def single_use_payment_method_cloned_to_connected_account
        Stripe::PaymentMethod.create(
          {
            customer: payment_method.payment_processor_customer_id,
            payment_method: payment_method.payment_processor_source_id
          },
          { stripe_account: account_id }
        )
      end
    end
  end
end
