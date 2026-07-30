// CampusHub API — servidor REST simples para suporte ao trabalho final de iOS.
// Persistência em ficheiro (db.json), criado a partir de seed.json no primeiro arranque.

const express = require('express');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const DB_PATH = path.join(__dirname, 'db.json');
const SEED_PATH = path.join(__dirname, 'seed.json');
const PORT = process.env.PORT || 3000;

function loadDB() {
  if (!fs.existsSync(DB_PATH)) {
    fs.copyFileSync(SEED_PATH, DB_PATH);
  }
  return JSON.parse(fs.readFileSync(DB_PATH, 'utf-8'));
}

function saveDB(db) {
  fs.writeFileSync(DB_PATH, JSON.stringify(db, null, 2), 'utf-8');
}

const app = express();
app.use(express.json());

app.get('/', (_req, res) => {
  res.json({ name: 'CampusHub API', status: 'ok' });
});

// --- Professores -----------------------------------------------------------
app.get('/api/professors', (_req, res) => {
  res.json(loadDB().professors);
});

// --- Unidades curriculares -------------------------------------------------
app.get('/api/units', (_req, res) => {
  res.json(loadDB().units);
});

// --- Horário / alocações ---------------------------------------------------
app.get('/api/schedule', (req, res) => {
  let schedule = loadDB().schedule;
  const { professorId, classGroup } = req.query;
  if (professorId) schedule = schedule.filter((s) => s.professor.id === professorId);
  if (classGroup) schedule = schedule.filter((s) => s.classGroup === classGroup);
  res.json(schedule);
});

// Duas aulas colidem se forem no mesmo dia e os intervalos [start, end) se sobrepuserem.
// Horas em formato "HH:mm" comparam corretamente como strings.
function overlaps(a, b) {
  return a.weekday === b.weekday && a.startTime < b.endTime && b.startTime < a.endTime;
}

app.post('/api/schedule', (req, res) => {
  const { unitId, professorId, weekday, startTime, endTime, room, classGroup } = req.body || {};
  if (!unitId || !professorId || !weekday || !startTime || !endTime || !room || !classGroup) {
    return res.status(400).json({ error: 'Campos obrigatórios em falta.' });
  }
  if (!(startTime < endTime)) {
    return res.status(400).json({ error: 'A hora de início deve ser anterior à hora de fim.' });
  }

  const db = loadDB();
  const unit = db.units.find((u) => u.id === unitId);
  const professor = db.professors.find((p) => p.id === professorId);
  if (!unit || !professor) {
    return res.status(404).json({ error: 'Professor ou unidade curricular inexistente.' });
  }

  const candidate = { weekday, startTime, endTime };
  const professorBusy = db.schedule.some(
    (s) => s.professor.id === professorId && overlaps(s, candidate)
  );
  if (professorBusy) {
    return res.status(409).json({ error: 'O professor já tem uma aula alocada nesse horário.' });
  }
  const roomBusy = db.schedule.some((s) => s.room === room && overlaps(s, candidate));
  if (roomBusy) {
    return res.status(409).json({ error: 'A sala já está ocupada nesse horário.' });
  }

  const entry = {
    id: crypto.randomUUID(),
    unit,
    professor,
    weekday,
    startTime,
    endTime,
    room,
    classGroup,
  };
  db.schedule.push(entry);
  saveDB(db);
  res.status(201).json(entry);
});

app.delete('/api/schedule/:id', (req, res) => {
  const db = loadDB();
  const index = db.schedule.findIndex((s) => s.id === req.params.id);
  if (index === -1) return res.status(404).json({ error: 'Alocação não encontrada.' });
  db.schedule.splice(index, 1);
  saveDB(db);
  res.status(204).end();
});

// --- Registo de horas ------------------------------------------------------
app.get('/api/timesheets', (req, res) => {
  let timesheets = loadDB().timesheets;
  const { professorId } = req.query;
  if (professorId) timesheets = timesheets.filter((t) => t.professorId === professorId);
  res.json(timesheets);
});

app.post('/api/timesheets', (req, res) => {
  const { professorId, date, hours, unitName } = req.body || {};
  if (!professorId || !date || !hours || !unitName) {
    return res.status(400).json({ error: 'Campos obrigatórios em falta.' });
  }
  if (typeof hours !== 'number' || hours <= 0 || hours > 12) {
    return res.status(400).json({ error: 'O número de horas deve estar entre 0 e 12.' });
  }

  const db = loadDB();
  const entry = {
    id: crypto.randomUUID(),
    professorId,
    date,
    hours,
    unitName,
    status: 'submitted',
  };
  db.timesheets.push(entry);
  saveDB(db);
  res.status(201).json(entry);
});

app.listen(PORT, () => {
  console.log(`CampusHub API a correr em http://localhost:${PORT}`);
});
