module supplychain::supplychain {
    use std::string::String;
    use sui::event;
    use sui::dynamic_object_field as ofield;
    use sui::vec_map;
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::balance::{Self, Balance};

    public struct Chains has key {
        id:UID,
        products:vec_map::VecMap<u64,Product>
    }
    public struct OwnerCapability has key { id: UID }
    public struct TitleDeed has key {id: UID}

    public struct Product has store{
        name: String,
        origin: address, // starting point
        current_owner: address, //current point
        status: String,
        history: vector<String>,  // history of the product
        document_hash: vector<u8>, // Hash of the document stored on IPFS
        verified:bool,
        sustainability_score: u8,  // Score indicating sustainability compliance
        ethical_practices_score: u8, // Score indicating ethical labor practices
        roles:vec_map::VecMap<String,address>
    }

    public struct RewardPool has key{
        id:UID,
        balance: Balance<SUI>
    }

    public struct ProductAdded has copy, drop, store {
        product_id: ID,
        status: String,
        origin: address,
    }

    const Status: vector<u8> = b"Registered";
    const Compliance_True :vector<u8> = b"Compliance verified to True";
    const Compliance_False :vector<u8> = b"Compliance verified to False";
    const Manufacturer:vector<u8> = b"Manufacturer";
    const Retailer:vector<u8> = b"Retailer";
    const Verifier:vector<u8> = b"Verifier";
    const NotAllowed:u64 = 1;
    
// init Chains
    fun init(ctx: &mut TxContext){
            let chain = Chains{
                id:object::new(ctx),
                products:vec_map::empty()
            };
            let rewardPool = RewardPool{
                id:object::new(ctx),
                balance:balance::zero()

            };
            transfer::transfer(OwnerCapability {id: object::new(ctx)} , ctx.sender());
            transfer::share_object(chain);
            transfer::share_object(rewardPool);
    }


// manufacturer register the product
    entry public fun registerProduct(
        idd:u64,
        name:String,
        chain:&mut Chains,
        document_hash: vector<u8>,
        ctx: &mut TxContext
        ){  
                            
           let origin = tx_context::sender(ctx);
           let status = Status.to_string();
           let history = vector::empty();
           let sustainability_score = 0;
           let ethical_practices_score = 0;
           let product = Product {
            name:name,
            origin:origin,
            current_owner: origin,
            status: status,
            history:history,
            document_hash:document_hash,
            verified:false,
            sustainability_score: sustainability_score,
            ethical_practices_score: ethical_practices_score,
            roles:vec_map::empty()
        };

        vec_map::insert(&mut chain.products,idd,product);
    }


// assigning roles manufacturer, retailer ,Verifier
    entry public fun assign_roles(
        idd:u64,
        retailer:address,
        verifier:address,
        chain:&mut Chains,
        ){
        let product = vec_map::get_mut(&mut chain.products,&idd);
        let origin = product.origin;
        let roles = &mut product.roles;
        vec_map::insert(roles,Manufacturer.to_string(),origin);
        vec_map::insert(roles,Retailer.to_string(),retailer);
        vec_map::insert(roles,Verifier.to_string(),verifier);
    }


// with travel of product owner is updated
    entry public fun updateOwner(
        idd:u64,
        chain:&mut Chains,
        ctx:&mut TxContext
        ){
            let product = vec_map::get_mut(&mut chain.products,&idd);
            let current_owner = tx_context::sender(ctx);
            let prev_owner = &mut product.current_owner;
            *prev_owner=current_owner;
    }


//"Shipped", "Received by Distributor", "In Store"
    entry public fun updateProductHistory(
        idd:u64,
        statuss:String,
        chain:&mut Chains,
        ){
        let product = vec_map::get_mut(&mut chain.products,&idd);
        let status = &mut product.status;
        let history = &mut product.history;
        *status = statuss;
        vector::push_back(history,*status);
    }


// to verify that the product is on the chain
    entry public fun verify(
        idd:u64,
        statee:bool,
        chain:&mut Chains,
        ctx:&mut TxContext
        ){
        let signer = tx_context::sender(ctx);
        let product = vec_map::get_mut(&mut chain.products,&idd);
        let roles = &mut product.roles;
        let verifier = vec_map::get(roles,&Verifier.to_string());

        assert!(signer==*verifier, NotAllowed);

        let state = &mut product.verified;
        let history = &mut product.history;
        *state = statee;
        if(statee ==false){
        vector::push_back(history,Compliance_False.to_string())}
        else {
            vector::push_back(history,Compliance_True.to_string());
        }

        }

// to give rewards
    
    public fun rewardDistribution(
        _: &OwnerCapability,
        rewardPool: &mut RewardPool, 
        idd:u64,
        chain:&mut Chains,
        amountt:u64,
        ctx:&mut TxContext
    ):Coin<SUI>{
        let amount = rewardPool.balance.value();
        rewardPool.balance.split(amount).into_coin(ctx)
    }

// function to set the reward
    entry public fun rewardAmount(
        rewardPool: &mut RewardPool, 
        amount:u64,
        payment: &mut Coin<SUI>, 
        ctx: &mut TxContext
        ){
            let paid = payment.balance_mut().split(amount);
            rewardPool.balance.join(paid);
        }   








}


















