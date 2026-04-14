using ApartmanApp.Business.DTOs.Aidat;
using ApartmanApp.Business.Services.Abstract;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanApp.API.Controllers;

[ApiController]
[Route("api/otomatik-aidat")]
[Authorize(Roles = "Admin")]
public class OtomatikAidatController(IOtomatikAidatService service) : ControllerBase
{
    /// Tüm otomatik aidat konfigürasyonları
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var result = await service.GetAllAsync();
        return Ok(result);
    }

    /// Kullanıcı için otomatik aidat oluştur veya güncelle
    [HttpPost]
    public async Task<IActionResult> Upsert([FromBody] OtomatikAidatUpsertDto dto)
    {
        var result = await service.UpsertAsync(dto);
        if (!result.Success) return BadRequest(result);
        return Ok(result);
    }

    /// Aktif/pasif geçiş
    [HttpPatch("{id:int}/toggle")]
    public async Task<IActionResult> Toggle(int id)
    {
        var result = await service.ToggleAktifAsync(id);
        if (!result.Success) return NotFound(result);
        return Ok(result);
    }

    /// Tutar güncelle
    [HttpPatch("{id:int}/tutar")]
    public async Task<IActionResult> UpdateTutar(int id, [FromBody] OtomatikAidatTutarGuncelleDto dto)
    {
        var result = await service.UpdateTutarAsync(id, dto);
        if (!result.Success) return BadRequest(result);
        return Ok(result);
    }

    /// Konfigürasyonu sil
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var result = await service.DeleteAsync(id);
        if (!result.Success) return NotFound(result);
        return Ok(result);
    }

    /// Belirli ay/yıl için otomatik aidat üret (manuel tetikleme)
    [HttpPost("uret")]
    public async Task<IActionResult> Uret([FromBody] AyYilDto dto)
    {
        var uretilen = await service.UretAylikAidatlarAsync(dto.Ay, dto.Yil);
        return Ok(new { uretilen, mesaj = $"{uretilen} aidat kaydı oluşturuldu." });
    }
}

public record AyYilDto(int Ay, int Yil);
