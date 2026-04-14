using ApartmanApp.Business.DTOs.Aidat;
using ApartmanApp.Business.Services.Abstract;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanApp.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AidatController(IAidatService aidatService) : ControllerBase
{
    /// Tüm aidat kayıtları (admin)
    [HttpGet]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAll()
    {
        var result = await aidatService.GetAllAsync();
        return Ok(result);
    }

    /// Belirli kullanıcının aidatları
    [HttpGet("kullanici/{kullaniciId:int}")]
    public async Task<IActionResult> GetByKullanici(int kullaniciId)
    {
        var result = await aidatService.GetByKullaniciIdAsync(kullaniciId);
        return Ok(result);
    }

    /// Tekil aidat detayı
    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
    {
        var result = await aidatService.GetByIdAsync(id);
        if (!result.Success)
            return NotFound(result);
        return Ok(result);
    }

    /// Yeni aidat kaydı oluştur (admin)
    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create([FromBody] AidatCreateDto dto)
    {
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
