using System.ComponentModel.DataAnnotations;

namespace ApartmanWeb.Models;

public class LoginViewModel
{
    [Required(ErrorMessage = "Email zorunludur")]
    [EmailAddress(ErrorMessage = "Gecerli bir email giriniz")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Sifre zorunludur")]
    public string Sifre { get; set; } = string.Empty;

    public string? ErrorMessage { get; set; }
}

public class LoginRequest
{
    public string Email { get; set; } = string.Empty;
    public string Sifre { get; set; } = string.Empty;
}

public class LoginResponse
{
    public bool Success { get; set; }
    public string? Message { get; set; }
    public LoginData? Data { get; set; }
}

public class LoginData
{
    public string Token { get; set; } = string.Empty;
    public LoginUser? User { get; set; }
}

public class LoginUser
{
    public int Id { get; set; }
    public string AdSoyad { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Rol { get; set; } = string.Empty;
    public string? DaireNo { get; set; }
}
