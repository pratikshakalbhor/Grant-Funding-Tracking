module MyModule::GrantFundingTracker {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    /// Struct representing a grant funding project with tracking capabilities
    struct Grant has store, key {
        total_received: u64,     // Total grant funds received
        total_spent: u64,        // Total funds spent from the grant
        budget_limit: u64,       // Maximum budget allocated for the grant
        recipient: address,      // Address of the grant recipient
    }

    /// Function to initialize a new grant with budget allocation
    /// Can only be called by the grant provider/administrator
    public fun initialize_grant(
        provider: &signer, 
        recipient: address, 
        budget_limit: u64
    ) {
        let grant = Grant {
            total_received: 0,
            total_spent: 0,
            budget_limit,
            recipient,
        };
        move_to(provider, grant);
    }

    /// Function to disburse grant funds to the recipient
    /// Includes automatic spending tracking when funds are used
    public fun disburse_and_track_spending(
        provider: &signer,
        recipient_address: address,
        disbursement_amount: u64,
        spending_amount: u64
    ) acquires Grant {
        let provider_address = signer::address_of(provider);
        let grant = borrow_global_mut<Grant>(provider_address);
        
        // Verify the recipient matches the grant recipient
        assert!(grant.recipient == recipient_address, 1);
        
        // Check if spending would exceed budget
        assert!(grant.total_spent + spending_amount <= grant.budget_limit, 2);
        
        // Transfer disbursement to recipient
        let disbursed_funds = coin::withdraw<AptosCoin>(provider, disbursement_amount);
        coin::deposit<AptosCoin>(recipient_address, disbursed_funds);
        
        // Update grant tracking
        grant.total_received = grant.total_received + disbursement_amount;
        grant.total_spent = grant.total_spent + spending_amount;
    }
}