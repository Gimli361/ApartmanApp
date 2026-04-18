using ApartmanApp.Business.Services.Abstract;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanApp.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class DaireController(IDaireService daireService) : ControllerBase
{
    [HttpGet("blok/{blokId:int}")]
    public async Task<IActionResult> GetByBlok(int blokId)
    {
        var result = await daireService.GetByBlokAsync(blokId);
        return Ok(result);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create([FromBody] DaireCreateRequest request)
    {
        var result = await daireService.CreateAsync(request.BlokId, request.DaireNo);
        if (!result.Success)
            return BadRequest(result);
        return Ok(result);
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        var result = await daireService.DeleteAsync(id);
        if (!result.Success)
            return NotFound(result);
        return Ok(result);
    }
}

public record DaireCreateRequest(int BlokId, string DaireNo);
