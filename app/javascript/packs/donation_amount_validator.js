document.addEventListener('DOMContentLoaded', function() {
    const amountInput = document.getElementById('subscription_amount_dollars');
    const warningMessage = document.getElementById('amount_warning');
  
    if (!amountInput || !warningMessage) {
      // No amount-entry form detected
      return;
    }
  
    // Function to validate and toggle warning
    function validateAmount() {
      const valid = parseFloat(amountInput.value) > 0 || amountInput.value === '';
      warningMessage.style.display = valid ? 'none' : 'block';
    }
  
    // Add event listener for real-time validation as user types
    amountInput.addEventListener('input', validateAmount);
  
    // Initial validation in case the field is pre-filled with an invalid value
    validateAmount();
  });