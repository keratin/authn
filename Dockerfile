FROM ruby:2.3-onbuild

EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
