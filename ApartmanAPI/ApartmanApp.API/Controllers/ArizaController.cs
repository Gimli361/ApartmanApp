using ApartmanApp.Business.DTOs.Ariza;
using ApartmanApp.Business.Services.Abstract;
using ApartmanApp.Business.Validators;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanApp.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ArizaController(IArizaService arizaService) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] string? blokNo = null)
    {
        var result = await arizaService.GetAllAsync(blokNo);
        return Ok(result);
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
    {
        var result = await arizaService.GetByIdAsync(id);
        if (!result.Success)
            return NotFound(result);
        return Ok(result);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] ArizaCreateDto dto)
    {
        var validator = new ArizaCreateValidator();
        var validation = await validator.ValidateAsync(dto);
        if (!validation.IsValid)
            return BadRequest(validation.Errors.Select(e => e.ErrorMessage));

        var result = await arizaService.CreateAsync(dto);
        if (!result.Success)
            return BadRequest(result);

        return CreatedAtAction(nameof(GetById), new { id = result.Data!.Id }, result);
    }

    [HttpPatch("{id:int}/durum")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateDurum(int id, [FromBody] ArizaDurumGuncelleDto dto)
    {
        var result = await arizaService.UpdateDurumAsync(id, dto);
        if (!result.Success)
            return NotFound(result);
        return Ok(result);
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        var result = await arizaService.DeleteAsync(id);
        if (!result.Success)
            return NotFound(result);
        return Ok(result);
    }
}
