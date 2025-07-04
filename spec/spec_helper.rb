# This file was generated by the `rails generate rspec:install` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# The generated `.rspec` file contains `--require spec_helper` which will cause
# this file to always be loaded, without a need to explicitly require it in any
# files.
#
# Given that it is always loaded, you are encouraged to keep this file as
# light-weight as possible. Requiring heavyweight dependencies from this file
# will add to the boot time of your test suite on EVERY test run, even for an
# individual file that may not need all of that loaded. Instead, consider making
# a separate helper file that requires the additional dependencies and performs
# the additional setup, and require it from the spec files that actually need
# it.
#
# The `.rspec` file also contains a few flags that are not defaults but that
# users commonly want.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # This option will default to `:apply_to_host_groups` in RSpec 4 (and will
  # have no way to turn it off -- the option exists only for backwards
  # compatibility in RSpec 3). It causes shared context metadata to be
  # inherited by the metadata hash of host groups and examples, rather than
  # triggering implicit auto-inclusion in groups with matching metadata.
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # The settings below are suggested to provide a good initial experience
  # with RSpec, but feel free to customize to your heart's content.
  # This allows you to limit a spec run to individual examples or groups
  # you care about by tagging them with `:focus` metadata. When nothing
  # is tagged with `:focus`, all examples get run. RSpec also provides
  # aliases for `it`, `describe`, and `context` that include `:focus`
  # metadata: `fit`, `fdescribe` and `fcontext`, respectively.
  config.filter_run_when_matching :focus

  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options. We recommend
  # you configure your source control system to ignore this file.
  config.example_status_persistence_file_path = 'spec/examples.txt'

  # Limits the available syntax to the non-monkey patched syntax that is
  # recommended. For more details, see:
  #   - http://rspec.info/blog/2012/06/rspecs-new-expectation-syntax/
  #   - http://www.teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   - http://rspec.info/blog/2014/05/notable-changes-in-rspec-3/#zero-monkey-patching-mode
  # config.disable_monkey_patching!

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = 'doc'
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  # config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed

  # config.before(:each) do
  #   Partner.find_or_create_by(name: Partner::DEFAULT_PARTNER_NAME) do |p|
  #     p.website_url = 'https://donational.org'
  #     p.description = 'Donational'
  #     p.donor_questions_schema = { questions: [] }
  #     p.payment_processor_account_id = ENV.fetch('DEFAULT_PAYMENT_PROCESSOR_ACCOUNT_ID')
  #   end
  # end

  config.before(:suite) do
    # reindex models
    SearchableOrganization.reindex

    # and disable callbacks
    Searchkick.disable_callbacks
  end

  config.around(:each, search: true) do |example|
    Searchkick.callbacks(true) do
      example.run
    end
  end

  config.before do
    Sidekiq::Worker.clear_all

    # To create a Stripe::PaymentIntent, we pass expand: ['charges.data.balance_transaction'] to obtain Stripe fee. Currently,
    # stripe-ruby-mock gem does not allow to expand the balance transaction object, so payment_intent[:charges][:data][0][:balance_transaction]
    # contains only the ID (i.e 'test_txn_1').
    # https://github.com/stripe-ruby-mock/stripe-ruby-mock/issues/109#issuecomment-275096253 found a workaround, which I adapted to expand balance_transaction.
    allow(Stripe::PaymentIntent).to receive(:create).and_wrap_original do |original_method, *args|
      payment_intent = original_method.call(*args)
      options = args.first
      expand = options.is_a?(Hash) && options[:expand] && options[:expand].include?('charges.data.balance_transaction')

      next payment_intent unless expand

      balance_transaction = payment_intent.charges.data.first.balance_transaction
      payment_intent.charges.data.first.balance_transaction = {
        id: balance_transaction,
        fee_details: [
          {
            amount: 20,
            currency: 'usd',
            description: 'Stripe processing fees',
            type: 'stripe_fee'
          }
        ]
      }

      payment_intent
    end
  end

  # Run tests that do not mock Stripe responses (and which use Stripe's live test server) by using `rspec -t live` flag.
  # This stops StripeMock from mocking http calls, and runs specs that have a 'live: true' flag.
  # https://github.com/donational-org/stripe-ruby-mock#live-testing
  if config.filter_manager.inclusions.rules.include?(:live)
    raise 'The API key provided is not a test API key. Please use a test API key.' if Stripe.api_key.exclude?('test')

    StripeMock.toggle_live(true)
    puts 'Running **live** tests against Stripe test server...'
  else
    config.filter_run_excluding :live
  end
end

RSpec::Matchers.define :appear_before do |later_content|
  match do |earlier_content|
    page.body.index(earlier_content) < page.body.index(later_content)
  end
end
