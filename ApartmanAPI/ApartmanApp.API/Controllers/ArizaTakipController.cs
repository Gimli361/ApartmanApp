using System.Security.Claims;
using ApartmanApp.Business.Services.Abstract;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanApp.API.Controllers;

[ApiController]
[Route("api/ariza")]
[Authorize]
public class ArizaTakipController(IArizaTakipService takipService) : ControllerBase
{
    private int CurrentUserId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    /// Arızayı takibe al
    [HttpPost("{id:int}/takip")]
    public async Task<IActionResult> TakipEt(int id)
    {
        var result = await takipService.TakipEtAsync(id, CurrentUserId);
        return Ok(result);
    }

    /// Arıza takibinden çık
    [HttpDelete("{id:int}/takip")]
    public async Task<IActionResult> TakiptenCik(int id)
    {
        var result = await takipService.TakiptenCikAsync(id, CurrentUserId);
        if (!result.Success)
            return NotFound(result);
        return Ok(result);
    }

    /// Arıza takip durumu (takip ediyor mu + takipçi sayısı)
    [HttpGet("{id:int}/takip-durumu")]
    public async Task<IActionResult> GetTakipDurumu(int id)
    {
        var dto = await takipService.GetTakipDurumuAsync(id, CurrentUserId);
        return Ok(dto);
    }

}
