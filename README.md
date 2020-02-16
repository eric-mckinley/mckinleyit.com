# Jekyll based Static Website

A Jekyll implementation of the [McKinley IT website](http://mckinleyit.com/)

## To Use

```
docker run --rm --volume="$PWD/static-site:/srv/jekyll" -p 12000:4000 -it jekyll/builder:3.8 jekyll serve
```

Visit site at [http://localhost:12000](http://localhost:12000)

 Generated content is found in PROJECT_DIR/_site

