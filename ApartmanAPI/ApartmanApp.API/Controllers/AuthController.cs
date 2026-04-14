using ApartmanApp.Business.DTOs.Auth;
using ApartmanApp.Business.Services.Abstract;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanApp.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController(IAuthService authService) : ControllerBase
{
    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Email) || string.IsNullOrWhiteSpace(dto.Sifre))
            return BadRequest("Email ve şifre zorunludur.");

        var result = await authService.LoginAsync(dto);
        if (!result.Success)
            return Unauthorized(result);

        return Ok(result);
    }
}
