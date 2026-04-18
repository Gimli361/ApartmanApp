using System.Security.Claims;
using ApartmanApp.Business.DTOs.Oylama;
using ApartmanApp.Business.Services.Abstract;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanApp.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class OylamaController(IOylamaService oylamaService) : ControllerBase
{
    private int CurrentUserId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    /// Tüm oylamalar (aktif+pasif)
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var result = await oylamaService.GetAllAsync(CurrentUserId);
        return Ok(result);
    }

    /// Oylama detayı — seçenekler ve oy oranları
    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
    {
        var result = await oylamaService.GetByIdAsync(id, CurrentUserId);
        if (!result.Success)
            return NotFound(result);
        return Ok(result);
    }

    /// Yeni oylama oluştur (sadece admin)
    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create([FromBody] OylamaCreateDto dto)
    {
        var result = await oylamaService.CreateAsync(dto, CurrentUserId);
        if (!result.Success)
            return BadRequest(result);
        return CreatedAtAction(nameof(GetById), new { id = result.Data!.Id }, result);
    }

    /// Oy ver
    [HttpPost("{id:int}/oy")]
    public async Task<IActionResult> OyVer(int id, [FromBody] OyVerDto dto)
    {
        var result = await oylamaService.OyVerAsync(id, dto.SecenekId, CurrentUserId);
        if (!result.Success)
            return BadRequest(result);
        return Ok(result);
    }

    /// Oy geri al
    [HttpDelete("{id:int}/oy")]
    public async Task<IActionResult> OyGeriAl(int id)
    {
        var result = await oylamaService.OyGeriAlAsync(id, CurrentUserId);
        if (!result.Success)
            return BadRequest(result);
        return Ok(result);
    }

    /// Aktif/pasif geçiş (sadece admin)
    [HttpPatch("{id:int}/toggle")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Toggle(int id)
    {
        var result = await oylamaService.ToggleAktifAsync(id);
        if (!result.Success)
            return NotFound(result);
        return Ok(result);
    }

    /// Oylama sil (sadece admin)
    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        var result = await oylamaService.DeleteAsync(id);
        if (!result.Success)
            return NotFound(result);
        return Ok(result);
    }
}
