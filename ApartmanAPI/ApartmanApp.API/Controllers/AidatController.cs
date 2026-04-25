using System.Security.Claims;
using ApartmanApp.Business.DTOs.Aidat;
using ApartmanApp.Business.Services.Abstract;
using ApartmanApp.Business.Validators;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanApp.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AidatController(IAidatService aidatService) : ControllerBase
{
    private bool TryGetCurrentUserId(out int id) =>
        int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out id) && id > 0;

    /// Tüm aidat kayıtları (admin)
    [HttpGet]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAll()
    {
        var result = await aidatService.GetAllAsync();
        return Ok(result);
    }

    /// Sayfalı tüm aidatlar (admin)
    [HttpGet("paged")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetPaged(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var result = await aidatService.GetPagedAsync(page, pageSize);
        return Ok(result);
    }

    /// Belirli kullanıcının aidatları (sadece sahip veya admin)
    [HttpGet("kullanici/{kullaniciId:int}")]
    public async Task<IActionResult> GetByKullanici(int kullaniciId)
    {
        if (!TryGetCurrentUserId(out var currentUserId))
            return Unauthorized();
        if (currentUserId != kullaniciId && !User.IsInRole("Admin"))
            return Forbid();

        var result = await aidatService.GetByKullaniciIdAsync(kullaniciId);
        return Ok(result);
    }

    /// Belirli kullanıcının sayfalı aidatları
    [HttpGet("kullanici/{kullaniciId:int}/paged")]
    public async Task<IActionResult> GetPagedByKullanici(
        int kullaniciId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        if (!TryGetCurrentUserId(out var currentUserId))
            return Unauthorized();
        if (currentUserId != kullaniciId && !User.IsInRole("Admin"))
            return Forbid();

        var result = await aidatService.GetPagedByKullaniciIdAsync(kullaniciId, page, pageSize);
        return Ok(result);
    }

    /// Tekil aidat detayı (sadece sahip veya admin)
    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
    {
        if (!TryGetCurrentUserId(out var currentUserId))
            return Unauthorized();

        var result = await aidatService.GetByIdAsync(id);
        if (!result.Success)
            return NotFound(result);

        if (result.Data!.KullaniciId != currentUserId && !User.IsInRole("Admin"))
            return Forbid();

        return Ok(result);
    }

    /// Yeni aidat kaydı oluştur (admin)
    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create([FromBody] AidatCreateDto dto)
    {
        var validation = await new AidatCreateValidator().ValidateAsync(dto);
        if (!validation.IsValid)
            return BadRequest(validation.Errors.Select(e => e.ErrorMessage));

        var result = await aidatService.CreateAsync(dto);
        if (!result.Success)
            return BadRequest(result);
        return CreatedAtAction(nameof(GetById), new { id = result.Data!.Id }, result);
    }

    /// Ödeme durumunu güncelle (admin)
    [HttpPatch("{id:int}/odemeDurumu")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateOdemeDurum(int id, [FromBody] AidatOdemeDurumGuncelleDto dto)
    {
        var result = await aidatService.UpdateOdemeDurumAsync(id, dto);
        if (!result.Success)
            return NotFound(result);
        return Ok(result);
    }

    /// Aidat kaydı sil (admin)
    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        var result = await aidatService.DeleteAsync(id);
        if (!result.Success)
            return NotFound(result);
        return Ok(result);
    }
}
