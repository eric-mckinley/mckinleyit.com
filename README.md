# Jekyll based Static Website

A Jekyll implementation of the [McKinley IT website](http://mckinleyit.com/)

## Build Website

```
docker run --rm --volume="$PWD/static-site:/srv/jekyll" -p 12000:4000 -it jekyll/builder:3.8 jekyll serve
```

Visit site at [http://localhost:12000](http://localhost:12000)

Live edit site while running as jekyll tracks changes

 Generated content is found in PROJECT_DIR/static-site/_site

## Build Infrastructure

```bash
cd terraform
terraform init
terraform apply
```

Own the email ( admin@yourdomain.com ) to accept the generated SSL cert.

### Publish Site

From Project dir
```
aws s3 sync static-site/_site s3://www.mckinleyit.com/
```
