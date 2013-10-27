module Wanko
  class BaseError < StandardError
  end

  class AuthError < BaseError
  end

  class ConnectionError < BaseError
  end

  class PathError < BaseError
  end
end

