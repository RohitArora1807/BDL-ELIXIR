defmodule ElixirApp.Accounts.PasswordHasher do
  @iterations 100_000
  @key_length  32

  def hash_pwd_salt(password) do
    salt = :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
    hash = derive(password, salt)
    "$pbkdf2-sha256$#{@iterations}$#{salt}$#{hash}"
  end

  def verify_pass(password, stored) do
    case String.split(stored, "$") do
      ["", "pbkdf2-sha256", _iter, salt, expected] ->
        actual = derive(password, salt)
        secure_compare(actual, expected)

      _ ->
        false
    end
  end

  # Constant-time penalty when no user found (prevents timing attacks)
  def no_user_verify do
    hash_pwd_salt("dummy_password_to_waste_time")
  end

  defp derive(password, salt) do
    :crypto.pbkdf2_hmac(:sha256, password, salt, @iterations, @key_length)
    |> Base.url_encode64(padding: false)
  end

  defp secure_compare(a, b) when byte_size(a) == byte_size(b) do
    :crypto.hash_equals(a, b)
  end
  defp secure_compare(_, _), do: false
end
