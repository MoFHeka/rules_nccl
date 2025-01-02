def if_local_nccl(if_true, if_false = []):
    is_local_nccl = %{is_local_nccl}
    if is_local_nccl:
        return if_true
    else:
        return if_false
