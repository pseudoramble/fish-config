function lzd --description 'docker-machine start && lazydocker'
  set machine_status (docker-machine status)
  
  if test $machine_status != 'Running'
    docker-machine start
  end

  eval (docker-machine env default)
  lazydocker
end