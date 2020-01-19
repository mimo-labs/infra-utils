desc "Prepare application migrations and statics"
task :prepare_application do
  on roles(:app) do |host|
    execute :docker, :exec, :mimo_api, "mockserver/manage.py", :migrate
    execute :docker, :exec, :mimo_api, "mockserver/manage.py", :collectstatic, "-c", "--noinput"
  end
end
