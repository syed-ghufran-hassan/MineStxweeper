import React, { useState } from 'react';
import { Difficulty } from '@/types';
import { Trophy, Medal, Award } from 'lucide-react';

export function Leaderboard() {
  const [selectedDifficulty, setSelectedDifficulty] = useState<Difficulty>(Difficulty.BEGINNER);

  // Mock data - in production, fetch from contract
  const leaderboard = [
    { rank: 1, player: 'ST1PQHQKV0...TPGZGM', time: 45, score: 2450 },
    { rank: 2, player: 'ST2EXAMPLE...WALLET', time: 52, score: 2380 },
    { rank: 3, player: 'ST3ANOTHER...PLAYER', time: 58, score: 2310 },
  ];

  return (
    <div className="min-h-screen bg-gray-900 pt-8">
      <div className="container mx-auto px-4">
        <h1 className="text-4xl font-bold text-white text-center mb-8 flex items-center justify-center gap-3">
           <Trophy size={40} className="text-yellow-400" />
           <span className="font-army">Global Leaderboard</span>
        </h1>

        {/* Difficulty Tabs */}
        <div className="flex justify-center gap-4 mb-8">
          <DifficultyTab
            label="Beginner"
            active={selectedDifficulty === Difficulty.BEGINNER}
            onClick={() => setSelectedDifficulty(Difficulty.BEGINNER)}
          />
          <DifficultyTab
            label="Intermediate"
            active={selectedDifficulty === Difficulty.INTERMEDIATE}
            onClick={() => setSelectedDifficulty(Difficulty.INTERMEDIATE)}
          />
          <DifficultyTab
            label="Expert"
            active={selectedDifficulty === Difficulty.EXPERT}
            onClick={() => setSelectedDifficulty(Difficulty.EXPERT)}
          />
        </div>

        {/* Leaderboard Table */}
        <div className="max-w-4xl mx-auto bg-gray-800 rounded-xl overflow-hidden">
          <table className="w-full">
            <thead className="bg-gray-700">
              <tr>
                <th className="px-6 py-4 text-left text-white">Rank</th>
                <th className="px-6 py-4 text-left text-white">Player</th>
                <th className="px-6 py-4 text-right text-white">Time</th>
                <th className="px-6 py-4 text-right text-white">Score</th>
              </tr>
            </thead>
            <tbody>
              {leaderboard.map((entry) => (
                <tr key={entry.rank} className="border-t border-gray-700 hover:bg-gray-750 transition">
                  <td className="px-6 py-4 text-white font-bold">
                    <div className="flex items-center gap-2">
                      {entry.rank === 1 && <Medal className="text-yellow-400" size={20} />}
                      {entry.rank === 2 && <Medal className="text-gray-400" size={20} />}
                      {entry.rank === 3 && <Medal className="text-orange-600" size={20} />}
                      #{entry.rank}
                    </div>
                  </td>
                  <td className="px-6 py-4 text-gray-300 font-mono">{entry.player}</td>
                  <td className="px-6 py-4 text-right text-primary-400 font-bold">{entry.time}s</td>
                  <td className="px-6 py-4 text-right text-green-400 font-bold">{entry.score}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

function DifficultyTab({ label, active, onClick }: { label: string; active: boolean; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className={`px-6 py-3 rounded-lg font-semibold transition ${
        active
          ? 'bg-primary-600 text-white'
          : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
      }`}
    >
      {label}
    </button>
  );
}
