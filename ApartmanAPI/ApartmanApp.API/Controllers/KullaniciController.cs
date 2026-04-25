using System.Security.Claims;
using ApartmanApp.Business.DTOs.Kullanici;
using ApartmanApp.Business.Services.Abstract;
using ApartmanApp.Business.Validators;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanApp.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class KullaniciController(IKullaniciService kullaniciService) : ControllerBase
{
    private int CurrentUserId =>
        int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;
    /// Oturumdaki kullanıcının bilgileri
    [HttpGet("me")]
    public async Task<IActionResult> GetMe()
    {
        var result = await kullaniciService.GetByIdAsync(CurrentUserId);
        if (!result.Success)
            return NotFound(result);
        return Ok(result);
    }

    [HttpGet]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAll()
    {
        var result = await kullaniciService.GetAllAsync();
        return Ok(result);
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
    {
        if (CurrentUserId != id && !User.IsInRole("Admin"))
            return Forbid();

        var result = await kullaniciService.GetByIdAsync(id);
        if (!result.Success)
            return NotFound(result);
        return Ok(result);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create([FromBody] KullaniciCreateDto dto)
    {
        var validator = new KullaniciCreateValidator();
        var validation = await validator.ValidateAsync(dto);
        if (!validation.IsValid)
            return BadRequest(validation.Errors.Select(e => e.ErrorMessage));

        var result = await kullaniciService.CreateAsync(dto);
        if (!result.Success)
            return BadRequest(result);

        return CreatedAtAction(nameof(GetById), new { id = result.Data!.Id }, result);
    }

    /// Kullanıcı bilgilerini güncelle (kendi veya admin)
    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, [FromBody] KullaniciUpdateDto dto)
    {
        // Sadece kendi profilini veya admin herhangi birini güncelleyebilir
        if (CurrentUserId != id && !User.IsInRole("Admin"))
            return Forbid();

        var validation = await new KullaniciUpdateValidator().ValidateAsync(dto);
        if (!validation.IsValid)
            return BadRequest(validation.Errors.Select(e => e.ErrorMessage));

        var result = await kullaniciService.UpdateAsync(id, dto);
        if (!result.Success)
            return BadRequest(result);
        return Ok(result);
    }

    /// Şifre güncelle (sadece kendi şifresi)
    [HttpPatch("{id:int}/sifre")]
    public async Task<IActionResult> UpdateSifre(int id, [FromBody] SifreGuncelleDto dto)
    {
        if (CurrentUserId != id)
            return Forbid();

        var validation = await new SifreGuncelleValidator().ValidateAsync(dto);
        if (!validation.IsValid)
            return BadRequest(validation.Errors.Select(e => e.ErrorMessage));

        var result = await kullaniciService.UpdateSifreAsync(id, dto);
        if (!result.Success)
            return BadRequest(result);
        return Ok(result);
    }

    /// Admin tarafından kullanıcı şifresi sıfırlama (eski şifre gerekmez)
    [HttpPatch("{id:int}/sifre-sifirla")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> AdminSifreSifirla(int id, [FromBody] AdminSifreSifirlaDto dto)
    {
        var validation = await new AdminSifreSifirlaValidator().ValidateAsync(dto);
        if (!validation.IsValid)
            return BadRequest(validation.Errors.Select(e => e.ErrorMessage));

        var result = await kullaniciService.AdminSifreSifirlaAsync(id, dto.YeniSifre);
        if (!result.Success)
            return BadRequest(result);
        return Ok(result);
    }

    [HttpPut("{id:int}/fcm-token")]
    public async Task<IActionResult> UpdateFcmToken(int id, [FromBody] FcmTokenDto dto)
    {
        if (CurrentUserId != id && !User.IsInRole("Admin"))
            return Forbid();

        if (string.IsNullOrWhiteSpace(dto.Token))
            return BadRequest("Token boş olamaz.");
        var result = await kullaniciService.UpdateFcmTokenAsync(id, dto.Token);
        if (!result.Success)
            return NotFound(result);
        return Ok(result);
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        var result = await kullaniciService.DeleteAsync(id);
        if (!result.Success)
            return NotFound(result);
        return Ok(result);
    }
}

public record FcmTokenDto(string Token);
