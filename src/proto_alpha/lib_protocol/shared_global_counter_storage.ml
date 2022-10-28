let increment_shared_global_counter ctx = 
  Storage.Contract.Shared_global_counter.get ctx >>=? 
  fun shared_global_counter -> 
    Storage.Contract.Shared_global_counter.update ctx (Z.succ shared_global_counter)